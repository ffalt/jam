import { Jam } from '@jam';
import LandscapeGenreNode = Jam.LandscapeGenreNode;
import LandscapeArtistNode = Jam.LandscapeArtistNode;

export interface LandscapeGenreRenderNode extends LandscapeGenreNode {
	kind: 'genre';
	color: string;
	normalizedName: string;
}

export interface LandscapeArtistRenderNode extends LandscapeArtistNode {
	kind: 'artist';
	color: string;
	normalizedName: string;
}

export interface GenreDatum {
	genre: LandscapeGenreRenderNode;
	gx: number;
	gy: number;
}

export interface LandscapeRenderData {
	genres: Array<LandscapeGenreRenderNode>;
	artists: Array<LandscapeArtistRenderNode>;
}
